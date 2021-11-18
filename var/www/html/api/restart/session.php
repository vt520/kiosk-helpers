<?php
	class domain_result extends json_object {}
	$result = new domain_result();
	$lock = atomic::get_lock("session");
	if(false !== $buffer = exec("do-reload-ui", $exec_output, $exit)) {
		$result->valid = true;
	}
	$result->exit_code = $exit;
	$result->status = $buffer;
	$result->output = $exec_output;
	$result->finish();

?>
