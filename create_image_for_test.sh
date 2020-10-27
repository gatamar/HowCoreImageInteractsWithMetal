convert -size 512x512 xc:#FF0000 im_R.png
convert -size 512x512 xc:#00FF00 im_G.png
convert -size 512x512 xc:#0000FF im_B.png

convert im_R.png im_G.png im_B.png +append im_RGB.png

rm im_R.png
rm im_G.png
rm im_B.png