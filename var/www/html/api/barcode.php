<?php
	class barcode_result extends json_object {
		public $raw_text = "";
		function __construct($contents) {
			$this->raw_text = $contents;
			parent::__construct(true);
		}
	}

	$result = new json_error(408, "No scan recived");

        $acm_device = "/dev/ttyACM0";
        $read_cmd = "\x16U\x0d;\x16T\x0d";
        $close_cmd = "\x16U\x0d";
        $timeout = 30;
        $exit = 0;

	$lock = atomic::get_lock("barcode");
        exec($test = "/usr/bin/stty -F $acm_device raw time 1",$message, $exit);
        if($exit === false) {
		(new json_error(500, "Permission Error: Scanner Boot"))->finish();
      	}

        $hWriter = fopen($acm_device, "w", false);
        $hReader = fopen($acm_device, "r", false);

        if(!$hReader) {
		(new json_error(500, "Permission Error: Scanner Read"))->finish();
	}
	if(!$hWriter) {
		(new json_error(500, "Permission Error: Scanner Write"))->finish();
	}

        stream_set_timeout($hReader, 1);
        stream_set_blocking($hReader, false);

        if($buffer_write = fwrite($hWriter, $read_cmd)) {
                $read_start = microtime(true);
                $buffer = null;
                while((microtime(true) - $read_start) < $timeout) {
                        $char = fgetc($hReader);
                        if($char == "") sleep(1);
                        if($char == "\x0d") break;
                        $buffer .= $char;
                }
                $result = new barcode_result($buffer);
        }
        fwrite($hWriter, $close_cmd);
        fclose($hReader); fclose($hWriter);
	unset($lock);
	$result->finish();
?>
