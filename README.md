# Wordpress stack on GCP PoC

## 1. The approach
For the wordpress container :
- use Packer to build the container image
- use ansible as provisioner : installing necessairy packeges for apache and php, download and exctract wordpress source code to document root, put necessairy configuration files.
- tag the image with the appropriate container host and project-id
- push the image to GCP container registry 
For the cloud infrastructure :
- Use terraform to provision VPC network, subnet, GKE cluster with its node pool, the ci/cd pipeline, kubernetes resources (deployment, service, ingress) .

## 2. Run the project
After creating GCP project and linking the git repository in the cloud build section in the GCP web connsole, use the local machine shell, after pulling the git repo :
- enter the infra directory put the values for variables in terraform.tfvars
- run terraform init (in infra directory)
- run terraform apply (in infra directory)
This provision all the cloud infrastructure for the PoC.

## 3. Components
In the wordress container image build, packer provision ansible in the ubuntu base with shell, then lunch ansible inside the container to provision apache, php components and setup wordpress.
apache is preconfigured with generic vhost that accepts any host name on port 80, and point on wordpress, the control of ssl termination and the host name will be flexible, and will be controled throw the cloud loadbalancer side (in our case kubernetes ingresss configuration).
in the runtime of thism image, the wp-config script get database variables (DB_HOST DB_NAME DB_USER DB_PASSWORD) from env, provided in kubernetes deployment resource.
the GKE cluster is private (VMs), for better security.

## 4. Problems
the first problem encountred, is unarchiving wordpress from url using : ansible.builtin.unarchive module
so, I switched to ansible shell module to download and unzip wordpress to destination directory.
the second problem, gcp services take time to be enabled, the first terraform apply stops on creating compute resources, after that can be reapplied.
the third problem is the health check for the deployment, the cloud backkend service pointing on the container get its health check path from readyness probe and liveness probe path configured in kubernetes deployment, and it must return status code 200, so I used valid path (/wp-includes/images/blank.gif) thyat returns 200.

## 5. Best HA/automated architecture and farther work
For best reliability, we can implement health check script (/healthcheck.php):
```
PRESS_CONFIG', __DIR__ . DIRECTORY_SEPARATOR . 'wp-config.php');
define('WORDPRESS_DIRECTORY', __DIR__ . DIRECTORY_SEPARATOR . 'wordpress');
define('WP_CONTENT_DIRECTORY', __DIR__ . DIRECTORY_SEPARATOR . 'wp-content');


// Health Check Flags
$_healthCheckStatus = true;
// Will stop the while loop
$_healthCheckCompleted = false;

// Just to be safe
try {
    // DoWhile loop here to simplify kicking out on a false $_healthCheckStatus
    do {
        // Check if wp-config exists
        if (!file_exists(WORDPRESS_CONFIG)) {
            $_healthCheckStatus = false;
        }

        // Make sure we have required directories
        $_healthCheckStatus = _dirIsValidAndNotEmpty(WORDPRESS_DIRECTORY);
        $_healthCheckStatus = _dirIsValidAndNotEmpty(WP_CONTENT_DIRECTORY);

        // Checks are complete, kick out the loop
        $_healthCheckCompleted = true; // Just say no to infinity and beyond
    } while (false === $_healthCheckCompleted && true === $_healthCheckStatus);
} catch (\Exception $e) {
    // Health check fails
    $_healthCheckStatus = false;
}

// If a bad healthcheck, return 404 to tell the load balancer we suck
if (false === $_healthCheckStatus) {
    header("HTTP/1.0 404 Not Found");
    ?>
    <html>
    <body><h1>Health is bad</h1></body>
    </html>
    <?php
    die();
} else {
    ?>
    <html>
    <body><h1>Health appears good</h1></body>
    </html>
    <?php
}

/**
 * Validates a directory and ensures it's not empty
 * @param string $dir
 * @return bool
 */
function _dirIsValidAndNotEmpty($dir) {
    // Make sure we have a directory
    if (is_dir($dir)) {
        // Make sure it's not empty
        $_dirIsNotEmpty = (new \FilesystemIterator($dir))->valid();
        if ($_dirIsNotEmpty) {
            return true;
        }
    }

    return false;
}
```
For scalability, we can use horizontal pod autoscaler based on external metric (in this case request counter provided from the load balancer).
For observability and monitoring, we can define SLOs for both availability and latency with error budget (for example: 99% availability in 28 days, with 1% error budget, and set alert on budget burn in 1 hour).
For RDS, we should use the managed database (Cloud SQL mysql offered by GCP),Cloud SQL offers a convenient, scalable, and secure solution for managing relational databases in the cloud. 
