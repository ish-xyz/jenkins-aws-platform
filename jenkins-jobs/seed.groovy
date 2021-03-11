/*List<String> folders = ['project-a', 'project-b', 'project-c', ...] // roughly 10-20 projects

def startupTasks = [:]

startupTasks["Folder Setup"] = {
  node("job_dsl") { stage("Folder Setup) {
    checkout scm
    sh "generate_some_files_read_by_job_dsl_code"
    jobDsl targets: "jobs/folders.groovy"
  } }
}

startupTasks["Self-Check"] = {
  // Checks that all .groovy files in jobs/** are consumed by exactly one jobDsl build step
}

parallel startupTasks

def allProjectJobs = [:]
for (int i = 0; i < folders.length; i++) {
    String projname = folders[i]
    allProjectJobs["Project $projname"] = {
        node("job_dsl") { stage("Project $projname") {
            checkout scm
            // Other versions of this have used stash&unstash, see commentary below
            sh "generate_some_files_read_by_job_dsl_code"
            // Classes in src/ are used to implement templates that set up each project similarly.
            jobDsl targets: "jobs/$projname/*.groovy", additionalClasspath: "src/"
        } }
    }
}
parallel allProjectJobs
*/
freeStyleJob('seed_job') {
    displayName('seed_job')
    description('Jenkins Seed Job')
    concurrentBuild(false)
    quietPeriod(5)
    logRotator(-1, 30)
    label('master')
/*
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
*/
    steps {
        dsl {
            external('jenkins-jobs/jobs/*.groovy')
        }
    }
}