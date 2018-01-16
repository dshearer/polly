Making operating-system specific packages of your project can be a great service to your users.  But it's also a pain.  
Linux distributions differ in which package-management system they use, and you need to take the time to learn how to do 
it correctly.  In the end, the scripts you write to make these packages are really just more pieces of your project, and 
they should be covered by automated tests along with the rest of it.

In an enterprise setting (or an open-source project with funding), we would have a Jenkins server for each OS that we support, 
and building and testing packages would be part of our Continuous Integration routine.  Unfortunately, this is not an option 
for most open-source projects.

Here I present a scheme (really, a bunch of Make files and a certain directory structure) that can test these 
packaging scripts for an arbitrary number of different (Unix) OSes on your own dev box.  I came up with it while working on 
making packages for my project [Jobber](https://dshearer.github.io/jobber/).

An important benefit of this scheme is that it can easily incorporate any automated system tests you may have, making it 
very easy for you to ensure that your program works on all the OSes you claim to support.

I have made a toy project that uses this system: [polly](https://github.com/dshearer/polly), named after a cat I had who 
was happy to pack up and travel with me regularly.  I'll use it as an example, showing how this scheme can be used to add 
support for CentOS 7 and Debian 9.

## Packaging: Out of Scope

I will not go into the details of how to make packages for different OSes.  However, the toy project does provide 
a good starting point if you need to make RPMs or Debian packages for non-daemon programs.  If you'd like an example of how 
to do it for a daemon, take a look at [Jobber](https://github.com/dshearer/jobber/tree/master/packaging).

## Prereqs

Here are the tools you'll need:
* [GNU Make](https://www.gnu.org/software/make/)
* [Vagrant](https://www.vagrantup.com/)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

VirtualBox is open-source virtualization software.

Vagrant is the key to this scheme.  It is a tool that makes it easy to automate creation, booting, shutdown, etc. of VMs.  
It's like Docker for VMs.

The toy project is written in Go, but you don't need the Go compiler on your system, as we'll do all the compilation on VMs.

# What It Does

To get started, please clone polly and then check out tag `initial`.

```bash
$ git clone https://github.com/dshearer/polly.git
$ cd polly
$ git checkout initial
```

This wonderful Go project initially looks like this:

```
|- src/github.com/dshearer/polly
    |- main.go
    |- meow.go
    |- meow_test.go
```

If you have Go installed, you can play around with it:

```shell
$ go test
PASS
ok  	.../polly	0.006s
$ go build
$ ./polly
meow! meow! meow! meow! meow!
```

Let's now take a look at how our scheme adds support for CentOS 7 and Debian 9.  Please check out the tip of master 
(`git checkout master`).

The project now looks like this:

```
|- src/github.com/dshearer/polly
    |- Makefile
    |- main.go
    |- meow.go
    |- meow_test.go
    |- packaging/
        |- Makefile
        |- centos_7/
            |- Makefile
            |- Vagrantfile
            |- polly.spec
            |- sources.mk
        |- debian_9/
            |- Makefile
            |- Vagrantfile
            |- debian-pkg/
                ...
            |- sources.mk
        |- head.mk
        |- sources.mk
        |- tail.mk
    |- system_test/
        |- meow_test.sh
    |- sources.mk
```

Yes, there's a lot of new crap, but making Linux packages isn't exactly simple.  Most of the  new files are in 
the directory `packaging`, in which we have one subdirectory for each of the OSes we wish to support --- 
`centos_7` and `debian_9`.  `packaging/centos_7/polly.spec` is our RPM spec file that we'll use to make the 
CentOS 7 package, and `packaging/debian_9/debian-pkg` contains all the standard files needed for making a Debian package.

We also have a new file at `system_test/meow_test.sh`.  This script contains any system tests that should be done 
on the program after it is installed.

So what does this give us?  If you have installed Vagrant and VirtualBox, try this:

```bash
$ make -C packaging -j test-vm
```

(The "-j" option causes this to be done for each OS in parallel.  Occasionally, I have seen this brick the VMs, 
which will cause the command to hang for a while.  If this happens to you, try the command without "-j".)

When this command is done, you will find a shiny new RPM at `packaging/results/centos_9/polly-1.0-1.el7.centos.x86_64.rpm` 
and a shiny new Debian package at `packaging/results/debian_9/polly_1.0-1_amd64.deb`.  Also, those packages will have 
been tested to ensure that they install polly correctly, and polly will have been tested to ensure it works on each of 
those OSes, using `system_test/meow_test.sh`.  You can see the results of the tests thus:

```bash
$ tail results/centos_7/test-vm.log
Installed:
  polly.x86_64 0:1.0-1.el7.centos                                               

Complete!
# run test
vagrant ssh --no-tty -c 'make -C polly-1.0/packaging/centos_7 test-local'
make: Entering directory `/home/vagrant/polly-1.0/packaging/centos_7'
"/home/vagrant/polly-1.0/system_test/meow_test.sh"
PASS
make: Leaving directory `/home/vagrant/polly-1.0/packaging/centos_7'

$ tail results/debian_9/test-vm.log 
(Reading database ... 41645 files and directories currently installed.)
Preparing to unpack polly_1.0-1_amd64.deb ...
Unpacking polly (1.0-1) ...
Setting up polly (1.0-1) ...
# run test
vagrant ssh --no-tty -c 'make -C polly-1.0/packaging/debian_9 test-local'
make: Entering directory '/home/vagrant/polly-1.0/packaging/debian_9'
"/home/vagrant/polly-1.0/system_test/meow_test.sh"
PASS
make: Leaving directory '/home/vagrant/polly-1.0/packaging/debian_9'
```

# How It Does It (Overview)

This whole process is orchestrated by Make files.  I know Make isn't used as much anymore, but it really does 
work well.  Moreover, it makes it much easier to build packages if your project can be built and installed with Make.

Making a package on both CentOS and Debian involves several OS-specific steps and OS-specific tools (namely, 
rpmbuild for CentOS and dpkg-buildpackage for Debian).  We of course need to automate those steps.  We also need 
to automate the steps that will be executed on our host machine --- for example, creating and starting the VMs.  
We might expect to be able to break our automation code into the following mutually exclusive categories:

- Automation code that is to be run on the host
- Automation code that is to be run on a CentOS 7 VM
- Automation code that is to be run on a Debian 9 VM

But it turns out that there's some overlap --- specifically, we need to run some of the code from the first 
category on the VMs.  So our solution takes this approach:

1. Make one system of Make files that does everything we need for every platform --- builds the program, builds 
the packages, runs unit tests, etc. --- ignoring the fact that not all these commands can actually be run on the same OS
1. Add logic that "magically" switches from the host to, say, the Debian VM, and then resumes execution on the VM

# How It Does It (Details)

At the root of the project is the main Make file --- `Makefile`.  Its important targets are

- `build`: build the program (actually, it calls `go install`)
- `install`: install the program to the appropriate place (for example, `/usr/local/bin`)
- `check`: run unit tests
- `dist`: make a source tarball

(The `dist` target is the reason for all those `sources.mk` files: those files list the source files in their respective 
directories, and `Makefile` imports them all to make the final list of all source files to be included in the tarball.)

Importantly, the main Make file does not concern itself with making packages or any other OS-specific activities.  
That stuff is covered by `packaging/centos_7/Makefile` and `packaging/debian_9/Makefile`.  Both of these contain the 
following targets:

- `pkg-local`: build the OS-specific package (assuming we are on a VM)
- `test-local`: Run `system_test/meow_test.sh` (assuming we are on a VM)
- `pkg-vm`: "Magically" run `pkg-local` on a VM with the appropriate OS (assuming we are on the host)
- `test-vm`: Run `pkg-vm`, then install the package on a VM with the appropriate OS, and finally "magically" run 
`test-local` on the VM (assuming we are on the host)

I want to be clear about something.  `packaging/centos_7/Makefile` and `packaging/debian_9/Makefile` *contain* 
`test-local`, `pkg-vm`, and `test-vm`, but these targets are *defined* in `packaging/tail.mk`, which those two Make 
files import.  In general, `packaging/<some_os>/Makefile` should define only OS-specific stuff.

For your convenience, here is the only target in `packaging/debian_9/Makefile`:

```Makefile
.PHONY : pkg-local
pkg-local : ${WORK_DIR}/${SRC_TARBALL}
	cp "${WORK_DIR}/${SRC_TARBALL}" \
		"${SRC_ROOT}/../polly_${VERSION}.orig.tar.gz"
	cp -R debian-pkg "${SRC_ROOT}/debian"
	cd "${SRC_ROOT}" && dpkg-buildpackage -us -uc
	mkdir -p "${DESTDIR}/"
	mv "${SRC_ROOT}"/../*.deb "${DESTDIR}/"
```

Lastly, `packaging/Makefile` also has targets `pkg-vm` and `test-vm`, but they just recursively call the same 
targets in each of the OS-specific subdirectories' Make files.

## The "Magic" Parts

The implementation of the "magic" parts is actually quite straightforward.  When `make -C packaging/centos_7 pkg-vm` 
is called, the script

1. Uses the main Make file's `dist` target to make a source tarball
1. Makes (or starts) a VM with the needed OS
1. Copies the tarball to the VM
1. Expands the tarball on the VM
1. Runs `make -C packaging/centos_7 pkg-local` on the VM

`test-vm` calls `test-local` on the VM in a similar way.

# The Next Step

I mentioned in the intro that this scheme naturally supports running system tests on each of these OSes.  In polly, 
`system_test/meow_test.sh` is a tiny toy system test for a tiny toy program.  In a real project, this opportunity to 
make system testing a part of your development process should not be ignored.

Jobber has [a good example](https://github.com/dshearer/jobber/tree/master/platform_tests), containing tests using 
[Robot Framework](http://robotframework.org/) of every major feature.  When I'm working on Jobber, I just need to do 
`make -C packaging -j test-vm` and watch the tests run on every supported OS, in parallel.  When they are done, there 
will be a beautiful Robot test report for each OS waiting for me in `packaging/results`.  

# Conclusion

Supporting multiple operating systems is hard, especially if you don't have infrastructure that automates away a lot 
of the tedious parts.  The scheme presented here provides such infrastructure, and I hope it has some ideas 
that would be useful in your own projects.
