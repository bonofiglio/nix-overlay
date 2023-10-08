latest_mac_version="arm64_sonoma"

# $1: dmg_url -> string
function calculate_sha256() {
    curl -s $1 | shasum -a 256 | head -c 64
}

# $1: name -> string
# $2: json_url -> string
# $3: calculate_sha256 -> "boolean" optional
function generate_json_from_cask() {
    local json="$(curl -s $2)"
    
    # Check that the version has changed before continuing
    local current="$(cat sources.json | jq -r ".[] | select(.name == \"$1\")")"
    if [ "$(echo $current | jq -r ".version")" == "$(echo $json | jq -r ".version")" ]; then
        echo $current > "./tmp/$1.json"
        return
    fi

    local version="$(echo $json | jq -r ".version")"
    local url="$(echo $json | jq -r ".url")"
    local source_root="$(echo $json | jq -r ".artifacts[] | select(.app != null) | .app[0]")"

    local sha256
    if [ "$3" == "true" ]; then
        sha256="$(calculate_sha256 $url)"
    else
        sha256="$(echo $json | jq -r ".sha256")"
    fi

    # Check if there is a specific arm64 version
    local mac_version_variation="$(echo $json | jq -r ".variations.$latest_mac_version")"
    if [ "$mac_version_variation" != null ]; then
        url="$(echo $mac_version_variation | jq -r ".url")"

        if [ "$3" == "true" ]; then
            sha256="$(calculate_sha256 $url)"
        else
            sha256="$(echo $mac_version_variation | jq -r ".sha256")"
        fi
    fi

	jq -n \
		--arg name "$(echo $1)" \
		--arg version "$(echo $version)" \
		--arg url "$(echo $url)" \
        --arg source_root "$(echo $source_root)" \
        --arg sha256 "$(echo $sha256)" \
		'{name: $name, version: $version, url: $url, source_root: $source_root, sha256: $sha256}' > "./tmp/$1.json"
}

mkdir ./tmp
touch sources.json

generate_json_from_cask "firefox" "https://formulae.brew.sh/api/cask/firefox.json" &
generate_json_from_cask "craft" "https://formulae.brew.sh/api/cask/craft.json" "true" &
generate_json_from_cask "height" "https://formulae.brew.sh/api/cask/height.json" &
generate_json_from_cask "ungoogled-chromium" "https://formulae.brew.sh/api/cask/eloston-chromium.json" &
generate_json_from_cask "vlc" "https://formulae.brew.sh/api/cask/vlc.json" &
generate_json_from_cask "arc" "https://formulae.brew.sh/api/cask/arc.json" &
generate_json_from_cask "blender" "https://formulae.brew.sh/api/cask/blender.json" &

wait

# Get all of the json files from the "tmp" folder and merge them into one
find ./tmp -type f -name "*.json" | xargs cat | jq -s . > ./sources.json

# Remove the "tmp" folder
rm -rf ./tmp
