<?php
	abstract class json_object {
		public $valid = false;
		function __construct($valid = false) {
			$this->valid = $valid;
			$this->type = get_called_class();
		}
		function finish($exit = 0) {
			echo(json_encode($this));
			exit($exit);
		}
	}
	class json_error extends json_object {
	        public $description;
	        public $code;
        	public function __construct($code, $description) {
			parent::__construct(false);
			$this->code = $code;
			$this->description=$description;
		}
		public function finish($exit = null) {
			$this->server_errors = error_get_last();
			header("{$_SERVER['SERVER_PROTOCOL']} {$this->code}: {$this->description}");
			parent::finish($this->code);
		}
	}

	class json_auth_result extends json_object {
		function __construct($valid = false) {
			$this->valid = $valid;
		}
	}
	class atomic {
		private $semaphore = null;
		private static $instances = [];
		protected function __construct($name) {
			$this->semaphore = sem_get(
				getmyinode() + hexdec(substr(md5($name), 24)));
			if(!sem_acquire($this->semaphore))
				throw new Exception("Failed to get {$name}");
			self::$instances[$name] = $this;
		}
		static function get_lock($name) {
			if(array_key_exists($name, self::$instances))
				return  self::$instances[$name];
			return new atomic($name);
		}

		function __destruct() {
			sem_release($this->semaphore);
			sem_remove($this->semaphore);
		}
	}
	if(!array_key_exists("auth", $_GET)) {
		(new json_error(401, "Unauthorized"))->finish();
	} else {
		$my_auth = strtolower(trim($_GET["auth"]));
                $check_auth = strtolower(trim(file_get_contents("/var/www/session")));
		if($my_auth !== $check_auth) (new json_error(402, "Access Denied"))->finish();
	}

	$module = strtolower($_GET["module"]);
	$basedir = dirname(__file__) . DIRECTORY_SEPARATOR . "api";
	$include_file = realpath($check_path = ($basedir . DIRECTORY_SEPARATOR . $module . ".php"));
	if(substr($include_file, 0, strlen($basedir)) !== $basedir) {
		(new json_error(404, "Invalid Command"))->finish();
	}
	require_once($include_file);

//	echo($check_path . "!!!" .$include_file);
//	var_dump($_GET);
//	switch($module) {
//		case "auth":
//	}
?>
