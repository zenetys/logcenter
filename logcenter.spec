%{!?logcenter_version: %define logcenter_version 1.0.0}
#define logcenter_revision HEAD

%define unforced_deps \
    bind-utils \
    gawk \
    jq \
    lua \
    openssl \
    rsyslog8z \
    rsync \
    sed \
    sqlite \
    tar \
    unzip \
    util-linux-core \
    xz \
    yq \

%define zenetys_git_source() %{lua:
    local version_source = 'https://github.com/zenetys/%s/archive/refs/tags/v%s.tar.gz#/%s-%s.tar.gz'
    local revision_source = 'http://git.zenetys.loc/data/projects/%s.git/snapshot/%s.tar.gz#/%s-%s.tar.gz'
    local name = rpm.expand("%{1}")
    local iname = name:gsub("%W", "_")
    local version = rpm.expand("%{"..iname.."_version}")
    local revision = rpm.expand("%{?"..iname.."_revision}")
    if revision == '' then print(version_source:format(name, version, name, version))
    else print(revision_source:format(name, revision, name, revision)) end
}

%global __brp_mangle_shebangs_exclude_from ^(/opt/logcenter/libexec/es-object-preprocessor)$

Name: logcenter
Version: %{logcenter_version}
Release: 1%{?dist}.zenetys
Summary: Logcenter integration
Group: Applications/System
License: MIT
URL: https://github.com/zenetys/logcenter

Source0: %zenetys_git_source logcenter

BuildArch: noarch

# standard
BuildRequires: nodejs >= 1:18
BuildRequires: tar
# yarn is available in epel
BuildRequires: yarnpkg

%description
Logcenter integration

%prep
%setup -c -T
mkdir logcenter
tar xvzf %{SOURCE0} --strip-components 1 -C logcenter

%build
cd logcenter

# archives wui
cd opt/logcenter/share/www/archives
node_modules_sig=$(md5sum package.json |cut -d ' ' -f 1)
if [ -f "%{_sourcedir}/archives_wui_node_modules_${node_modules_sig}_%{_arch}.tar.xz" ]; then
    tar xJf "%{_sourcedir}/archives_wui_node_modules_${node_modules_sig}_%{_arch}.tar.xz"
else
    yarn
    tar cJf "%{_sourcedir}/archives_wui_node_modules_${node_modules_sig}_%{_arch}.tar.xz" \
        node_modules yarn.lock
fi
yarn build

%install
cd logcenter
mkdir -p -m 755 %{buildroot}/etc/logcenter
mkdir -p -m 755 %{buildroot}/opt/logcenter
mkdir -p -m 755 %{buildroot}/opt/logcenter/share/www/archives
mkdir -p -m 755 %{buildroot}/var/log/logcenter
tar c -C opt/logcenter/ --exclude share/www/archives . |tar x -C %{buildroot}/opt/logcenter/
cp -RT --preserve=timestamp ./opt/logcenter/share/www/archives/dist/ %{buildroot}/opt/logcenter/share/www/archives/
cd ..

unforced_deps=( %{unforced_deps} )
(IFS=$'\n'; echo "${unforced_deps[*]}") \
    > %{buildroot}/opt/logcenter/share/unforced_deps

%posttrans
ch=$'\x1b[7;34m'; cc=$'\x1b[0;34m'; crst=$'\x1b[0m';
cat <<EOF

${ch}# %{name}${crst}
This RPM does not enforce most dependencies.
Run the following command to install them manually:
${cc}dnf shell <(sed -e 's,^,install ,; \$arun' /opt/logcenter/share/unforced_deps)${crst}

EOF

%files
/etc/logcenter
/opt/logcenter
/var/log/logcenter
