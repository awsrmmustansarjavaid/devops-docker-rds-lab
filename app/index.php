<?php
require 'vendor/autoload.php';

use Aws\SecretsManager\SecretsManagerClient;
use Aws\Exception\AwsException;

$client = new SecretsManagerClient([
    'version' => 'latest',
    'region'  => 'us-east-1'
]);

$secretName = "CafeDevDBSM"; // your secret name

try {
    $result = $client->getSecretValue([
        'SecretId' => $secretName,
    ]);

    $secret = json_decode($result['SecretString'], true);

    $host = $secret['host'];
    $user = $secret['username'];
    $password = $secret['password'];
    $dbname = $secret['dbname'];

    $conn = new mysqli($host, $user, $password, $dbname);

    if ($conn->connect_error) {
        die("Database connection failed: " . $conn->connect_error);
    }

    echo "<h1>DevOps Lab Connected to RDS Successfully via Secrets Manager</h1>";

} catch (AwsException $e) {
    echo "<h1>Error retrieving secret: " . $e->getMessage() . "</h1>";
}
?>