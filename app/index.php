<?php
require 'vendor/autoload.php';

use Aws\SecretsManager\SecretsManagerClient;
use Aws\Exception\AwsException;

// AWS Region
$region = 'us-east-1';
$secretName = 'CafeDevDBSM'; // Your Secrets Manager secret name

// Create Secrets Manager client
$client = new SecretsManagerClient([
    'version' => 'latest',
    'region'  => $region,
]);

try {
    $result = $client->getSecretValue([
        'SecretId' => $secretName,
    ]);
    $secret = json_decode($result['SecretString'], true);

    $host = $secret['host'];
    $dbname = $secret['dbname'];
    $username = $secret['username'];
    $password = $secret['password'];

    $mysqli = new mysqli($host, $username, $password, $dbname);

    if ($mysqli->connect_errno) {
        echo "Failed to connect to MySQL: " . $mysqli->connect_error;
        exit();
    }

    echo "<h1>DevOps Lab Connected to RDS Successfully ✅</h1>";

    $query = $mysqli->query("SELECT NOW() AS time");
    $row = $query->fetch_assoc();
    echo "<p>Server time: " . $row['time'] . "</p>";

    $mysqli->close();
} catch (AwsException $e) {
    echo "Error retrieving secret: " . $e->getMessage();
}