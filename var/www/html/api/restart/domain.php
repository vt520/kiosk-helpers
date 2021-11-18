<?php
	class domain_result extends json_object {}
	$result = new domain_result();
	$lock = atomic::get_lock("domain");
	if($buffer = exec("do-reload-domain", $exec_output, $exit)) {
		$result->valid = true;
	}
	$result->error = error_get_last();
	$result->exit_code = $exit;
	$result->status = $buffer;
	$result->output = $exec_output;
	$result->finish();

?>
