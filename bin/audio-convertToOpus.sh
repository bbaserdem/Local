#!/bin/bash
# Batch convert files in the current (or given) directory from mp3 to ogg

if [ -n "${1}" ] ; then
    input_dir="${1}"
else
    input_dir="$(pwd)"
fi
[ -d "${input_dir}" ] || echo "Directory ${input_dir} does not exist, or is not a directory."

# Bunch the outputs to a directory
output_dir="${input_dir}/Opus"
mkdir --parents "${output_dir}"

# Convert mp3 files
for input_file in "${input_dir}/"*.mp3; do
    # Guard
    [ -f "${input_file}" ] || break
    # Get full filename by removing the last 4 letters
    this_name="$(basename "${input_file::-4}")"
    output_file="${output_dir}/${this_name}.opus"
    # Do conversionutput_file
    ffmpeg -i "${input_file}" -c:a libopus "${output_file}"
done

# Convert flac files
for input_file in "${input_dir}/"*.flac; do
    # Guard
    [ -f "${input_file}" ] || break
    # Get full filename by removing the last 4 letters
    this_name="$(basename "${input_file::-5}")"
    output_file="${output_dir}/${this_name}.opus"
    # Do conversionutput_file
    ffmpeg -i "${input_file}" -map 0:a -codec:a libopus -b:a 192k -vbr on "${output_file}"
done

# Convert m4a files
for input_file in "${input_dir}/"*.m4a; do
    # Guard
    [ -f "${input_file}" ] || break
    # Get full filename by removing the last 4 letters
    this_name="$(basename "${input_file::-4}")"
    output_file="${output_dir}/${this_name}.opus"
    # Do conversionutput_file
    ffmpeg -i "${input_file}" -map 0:a -codec:a libopus -b:a 192k -vbr on "${output_file}"
done
