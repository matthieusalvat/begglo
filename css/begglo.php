<?php
	header('Content-type: text/plain');
	echo "{";
	print '"host" : "'.$_ENV['HTTP_HOST'].'"';
	echo "}";
?>