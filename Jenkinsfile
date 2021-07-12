pipeline {
    agent any
    options {
      timeout(30)
      // This is required if you want to clean before build
      skipDefaultCheckout(true)
    }
    environment {
	    nexus_version = "nexus3"
        nexus_protocol = "http"
        nexus_url = "localhost:8081"
        nexus_repository = "maven-snapshots"
        nexus_credentials = "nexus.credentials"
		docker_credentials = "dockerhub.credentials"
		docker_registry = ""
        docker_image = ""        
    }
    stages {
		/**stage("CheckOut") {
			steps {
				echo "Checkout the Code Repository..."
				git  branch: "master", credentialsId: "git.credentials", url: "https://github.com/sreeni72/mule-k8-demo.git"
			}
		}**/
		stage("Load Configuration") {
			steps {
				echo "Load Configuration..."
				script {
				    pom = readMavenPom file: "pom.xml";
				}
				echo "*** artifactId: ${pom.artifactId}, group: ${pom.groupId}, packaging: ${pom.packaging}, version: ${pom.version}";
				echo "Jenkins Job Name : ${env.JOB_NAME}..."
				echo "Jenkins Build Number : ${env.BUILD_NUMBER}..."   				
			}
		}
        stage("Maven Clean Package") {
			steps {
			    echo "Building ${env.JOB_NAME}..."
				echo "Build the Mule Application..." 
				bat "mvn clean package"
			}
		}
		stage("SonarQube analysis") {
			steps {
				echo "Code Review With SonarQube Rules..." 
				withSonarQubeEnv('SonarQube-Server') {
                    bat "mvn sonar:sonar"
                }
             /**   sleep(60)
                timeout(time: 1, unit: 'MINUTES') {
                	script{
                    	def qg = waitForQualityGate()
                    	print "Finished waiting"
                        if (qg.status != 'OK') {
                        	error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }**/
			}
		}
		stage("Deploy To Nexus") {
            steps {
			    // use profile nexus (-P nexus) to deploy to Nexus.
                //withCredentials([usernamePassword(credentialsId: 'nexus.credentials', passwordVariable: 'nexus_password', usernameVariable: 'nexus_user')]) {
                //    bat "mvn clean deploy -P nexus"
                //}
               	script {
					filesByGlob = findFiles(glob: "target/*.jar");
					artifactPath = filesByGlob[0].path;
					artifactExists = fileExists artifactPath;
					if(artifactExists) {
						echo "*** File: ${artifactPath}, group: ${pom.groupId}, packaging: ${pom.packaging}, version ${pom.version}";
						nexusArtifactUploader(
							nexusVersion: "${nexus_version}",
							protocol: "${nexus_protocol}",
							nexusUrl: "${nexus_url}",
							groupId: "${pom.groupId}",
							version: "${pom.version}",
							repository: "${nexus_repository}",
							credentialsId: "${nexus_credentials}",
							artifacts: [
								[artifactId: "${pom.artifactId}",
								classifier: "",
								file: artifactPath,
								type: "jar"],
								[artifactId: "${pom.artifactId}",
								classifier: "",
								file: "pom.xml",
								type: "pom"]
							]
						);
					} else {
						error "*** File: ${artifactPath}, could not be found";
					}
				}
            }
        }
        stage('Build Docker Image') {
			steps{
			    script {
				    withCredentials([usernamePassword(credentialsId: 'dockerhub.credentials', passwordVariable: 'docker_password', usernameVariable: 'docker_user')]) {
					    docker_registry = "${docker_user}/${pom.artifactId}"
				    }
				    docker_image = docker.build docker_registry + ":${BUILD_NUMBER}"
			    }
			}
		}
		stage('Push Docker Image') {
			steps{
				script {
					docker.withRegistry( '', docker_credentials ) {
						docker_image.push()
					}
				}
				bat "docker rmi $docker_registry:${BUILD_NUMBER}"
			}
		}
	}
    post {
        // Clean after build
        always {
            cleanWs()
        }
    }  
}