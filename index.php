<html>
	<head>
		<title>Promt 2</title>
	</head>
	<body>
		<?php
			shell_exec("/usr/bin/git -C /home/admin/admin pull");
			shell_exec("chmod -R ug+rwx /home/admin/admin");
			$out = htmlentities(shell_exec('/home/admin/admin/Watchdog.sh /home/admin/admin'));
			echo "<pre>$out</pre>";
		?>
	</body>
</html>
