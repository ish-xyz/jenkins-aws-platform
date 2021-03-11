def allJobs = [:]

for (int i = 0; i < 50; i++) {
    String projname = folders[i]
    def jobName = "job_" + jobName + ".groovy"
    allJobs["job $jobName"] = {
        freeStyleJob("$jobName") {
            displayName("$jobName")
            label('master')

            steps {
                dsl {
                    external("jenkins-jobs/jobs/$jobName")
                }
            }
        }
    }
}
parallel allJobs

/*

freeStyleJob('seed_job') {
    displayName('seed_job')
    description('Jenkins Seed Job')
    concurrentBuild(false)
    quietPeriod(5)
    logRotator(-1, 30)
    label('master')

    properties{
        githubProjectUrl("https://github.com/ish-xyz/jenkins-aws-platform.git")
    }
    scm {
        git {
            remote {
                url("https://github.com/ish-xyz/jenkins-aws-platform.git")
                //credentials('')
                name('origin')
            }
            branch('experiment')
        }
    }

    steps {
        dsl {
            external('jenkins-jobs/jobs/*.groovy')
        }
    }
}