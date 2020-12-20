folder("examples") {
    description 'This example shows basic folder/job creation.'
}

job("examples/example-job") {
    scm {
        github repo
    }
    triggers {
        scm 'H/5 * * * *'
    }
    steps {
        print "THIS JOB HAS BEEN CREATED AUTOMATICALLY"
    }
}
