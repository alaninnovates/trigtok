count=1
while [ $count -lt 21 ]
do
ffmpeg -i sliceit_part${count}.mp4 -vf "scale=-1:1920,crop=1080:1920:(in_w-1080)/2:0" sliceit_${count}.mp4
((count++))
done
