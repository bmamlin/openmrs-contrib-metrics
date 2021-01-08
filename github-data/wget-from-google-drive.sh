# Fetch Google Drive files
jq -r '.[] | [.id, .name] | join(" ")' google-drive-files.json | while read -r fileId fileName; do
  if [ -f "$fileName" ]; then
    echo "skipping $fileName because it already exists"
  else
    printf "downloading $fileName..."
    curl -sc /tmp/cookie "https://drive.google.com/uc?export=download&id=${fileId}" > /dev/null
    code="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"  
    curl -sLb /tmp/cookie "https://drive.google.com/uc?export=download&confirm=${code}&id=${fileId}" -o ${fileName}
    echo "done"
  fi
done