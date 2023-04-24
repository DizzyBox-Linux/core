stage1:
	./build.sh
stage2:
	sudo ./finish_image.sh
do: stage1 stage2