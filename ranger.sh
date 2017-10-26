#!/bin/bash
set -e
[ $# -ne 1 ] && echo "Pas de fichier spécifié" >&2 && exit 1

ARCHIVE="$1"
CATEGORIES=("Attestations fiscales" "Documents" "Factures" "Relevés" "Santé")

elementIn() {
	local e match="$1"
	shift
	for e; do
		[[ "$e" == "$match" ]] && echo "$e" && return 0
	done
	return 1
}

7z l -slt "$ARCHIVE" | grep -e '^Path = ' | while read z1 z2 file; do
	[ "$file" == "$ARCHIVE" ] && continue
	echo "$file"
	src="${file%%/*}"
	provider="${src% - *}"
	category="${src##* - }"
	if [ -z "$(elementIn "$category" "${CATEGORIES[@]}")" ]; then
		case "$category" in
			"Vos Documents De Santé")
				category="Santé"
				;;
			"Vos Documents Dématérialisés")
				if [ "${provider:0:4}" == "CPAM" ]; then
					category="Santé"
				else
					category="Autres/$category"
				fi
				;;
			*)
				category="Autres/$category"
				;;
		esac
	fi
	target="${file#*/}"
	case "$src" in
		"Impots.gouv.fr - Documents")
			target="$(echo "$target" | sed -e 's|\( - télédéclarée le \)\([0-9][0-9]\)/\([0-9][0-9]\)/\([0-9][0-9][0-9][0-9]\)\( à [0-9][0-9]*h[0-9][0-9].pdf\)$|\1\4_\3_\2\5|')"
			;;
		"Société Générale - Relevés")
			target="$(echo "$target" | sed -e 's|\( au \)\([0-9][0-9]\)/\([0-9][0-9]\)/\([0-9][0-9][0-9][0-9]\)\(.pdf\)$|\1\4_\3_\2\5|')"
			;;
		*)
			;;
	esac
	echo "$file : $category/$provider/$target"
	mkdir -p "$category/$provider"
	7z x "$ARCHIVE" "$file" -so > "$category/$provider/$target"
done

