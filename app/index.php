<?php

require 'vendor/autoload.php';

use Aws\SecretsManager\SecretsManagerClient;

$client = new SecretsManagerClient([
    'version' => 'latest',
    'region'  => 'us-east-1'
]);

$secretName = "CafeDevDBSM";

$result = $client->getSecretValue([
    'SecretId' => $secretName,
]);

$secret = json_decode($result['SecretString'], true);

$host = $secret['host'];
$user = $secret['username'];
$pass = $secret['password'];
$db   = $secret['dbname'];

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Connection failed");
}

echo "<h1>DevOps Lab Connected to RDS Successfully</h1>";

?>