# Create the directory if it doesn't exist
mkdir -p ~/0/

yt-dlp \
  -P ~/0/ \
  "https://www.youtube.com/watch?v=phZfIA9fAUM" \
  "https://www.youtube.com/watch?v=-FkaY6bk_Ts" \
  "https://www.youtube.com/watch?v=_5Lr6fDIZG8" \
  "https://www.youtube.com/watch?v=Jm53-TWJjqc"
