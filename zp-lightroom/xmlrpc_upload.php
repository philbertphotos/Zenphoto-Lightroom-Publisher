<?php

if(!copy($_FILES["photo"]["tmp_name"], $_FILES["photo"]["name"]))
	echo "error";

?>

