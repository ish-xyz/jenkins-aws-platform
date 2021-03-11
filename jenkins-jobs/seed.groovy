node {
    stage('Jobs provisioning') {
        def allJobs = [:]

        for (int i = 0; i < 50; i++) {
            def jobName = "job_${i}.groovy"
            allJobs["job ${jobName}"] = {
                node("${jobName}") { 
                    stage("Create Job ${jobName}") {
                        jobDsl targets: "jenkins-jobs/jobs/${jobName}.groovy"
                    } 
                }
            }
        }
        parallel allJobs
    }
}
