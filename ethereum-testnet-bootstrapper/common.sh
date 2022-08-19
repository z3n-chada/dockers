function record_image_failure() {
	echo $1 >> $FAILED_IMAGES_LOG
}
