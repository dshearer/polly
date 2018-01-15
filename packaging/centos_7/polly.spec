Name: polly
Version:    %{_pkg_version}
Release:    %{_pkg_release}%{?dist}
Summary: Polly the Cat
License: MIT
URL: http://github.com/dshearer/polly
Source0: polly-%{_pkg_version}.tgz
BuildRequires: golang >= 1.8
Prefix: /usr/local

%define debug_package %{nil}

%description
Polly says "Meow".

%files
%attr(0755,root,root) /usr/local/bin/polly

%prep
%setup -q
GO_WKSPC="%{_builddir}/go_workspace"
mkdir -p "${GO_WKSPC}/src/github.com/dshearer"
cp -R "%{_builddir}/polly-%{_pkg_version}" "${GO_WKSPC}/src/github.com/dshearer/polly"
echo "GO_WKSPC=${GO_WKSPC}" > "%{_builddir}/vars"

%build
source "%{_builddir}/vars"
make %{?_smp_mflags} -C "${GO_WKSPC}/src/github.com/dshearer/polly" build check

%install
source "%{_builddir}/vars"
%make_install -C "${GO_WKSPC}/src/github.com/dshearer/polly" install

%changelog
