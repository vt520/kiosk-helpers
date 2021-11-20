<?php
	class auth_token {
		public $valid = false;
		function __construct($is_valid) {
			$this->valid = $is_valid;
		}
	}

	if(array_key_exists("auth", $_GET)) {
		$my_auth = strtolower(trim($_GET["auth"]));
		$check_auth = strtolower(trim(file_get_contents("/var/www/session")));
		$r = new auth_token($my_auth == $check_auth);
		echo(json_encode($r));
	} else {
		header("HTTP/1.1 404 Not Found");
		echo($check_file . "Fart");
	}
?>
