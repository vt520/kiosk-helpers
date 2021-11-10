<?php
	class domain_result extends json_object {}
	$result = new domain_result();
	$lock = atomic::get_lock("domain");
	if(array_key_exists("force", $_GET) && $_GET["force"] = "skywalker") {
		if($buffer = exec("do-not-use -yes-reboot-hard", $exec_output, $exit)) {
			$result->valid = true;
		}
	} else {
		$buffer = "Supply force and the family name to run this";
	}
	$result->error = error_get_last();
	$result->exit_code = $exit;
	$result->status = $buffer;
	$result->output = $exec_output;
	$result->finish();

?>
