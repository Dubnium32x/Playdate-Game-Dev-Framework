#!/bin/bash
# Generate a tileset with all 4 flip variants for each 16x16 tile
INPUT="/home/dylan/Documents/playdate projects/Playdate-Game-Dev-Framework/source/sprites/tileset/SPGSolidTileHeightSemiSolids.png"
OUTPUT="/home/dylan/Documents/playdate projects/Playdate-Game-Dev-Framework/source/sprites/tileset/SPGSolidTileHeightSemiSolids_flipped.png"
TILESIZE=16
# Get tileset dimensions
WIDTH=$(identify -format "%w" "$INPUT")
HEIGHT=$(identify -format "%h" "$INPUT")
TILES_X=$((WIDTH / TILESIZE))
TILES_Y=$((HEIGHT / TILESIZE))
# Create a temp directory
TMPDIR=$(mktemp -d)
cd "$TMPDIR"
# Slice, flip, and assemble
for ((y=0; y<TILES_Y; y++)); do
  for ((x=0; x<TILES_X; x++)); do
    tile="tile_${y}_${x}.png"
    convert "$INPUT" -crop ${TILESIZE}x${TILESIZE}+$((x*TILESIZE))+$((y*TILESIZE)) +repage "$tile"
    convert "$tile" "${tile%.png}_h.png" -flop
    convert "$tile" "${tile%.png}_v.png" -flip
    convert "$tile" -flop -flip "${tile%.png}_hv.png"
    convert +append "$tile" "${tile%.png}_h.png" "${tile%.png}_v.png" "${tile%.png}_hv.png" "row_${y}_${x}.png"
  done
 done
# Assemble rows
for ((y=0; y<TILES_Y; y++)); do
  convert +append $(for ((x=0; x<TILES_X; x++)); do echo "row_${y}_${x}.png"; done) "fullrow_${y}.png"
done
# Stack all rows vertically
convert -append $(for ((y=0; y<TILES_Y; y++)); do echo "fullrow_${y}.png"; done) "$OUTPUT"
# Clean up
cd /
rm -rf "$TMPDIR"
# Generate a tileset with all 4 flip variants for the entire image, appended horizontally
INPUT="/home/dylan/Documents/playdate projects/Playdate-Game-Dev-Framework/source/sprites/tileset/SPGSolidTileHeightSemiSolids.png"
OUTPUT="/home/dylan/Documents/playdate projects/Playdate-Game-Dev-Framework/source/sprites/tileset/SPGSolidTileHeightSemiSolids_flipped.png"

convert \
  "$INPUT" \
  \( "$INPUT" -flop \) \
  \( "$INPUT" -flip \) \
  \( "$INPUT" -flop -flip \) \
  +append "$OUTPUT"

echo "Done! Output: $OUTPUT"
