<?php
	/*
		A simple class to test that semaphore locking works
		returns an object with execution time;

		By design this will start counting on creation,
		try to acquire a lock,
		sleep for 10
		release lock
		calculate execution time
		return result
	*/

	class toast_result extends json_object {
		function __construct($valid = true) {
			parent::__construct($valid);
			$this->start = microtime(true);
		}
	}
	$result = new toast_result(true);
	$r = atomic::get_lock("toast");
	sleep(30);
	unset($r);
	$result->exec = (microtime(true) - $result->start);
	$result->finish();
?>
