#!/bin/sh

if [ -d /tmp/repoclone ]; then
	rm -rf /tmp/repoclone
fi

cd / && cp -R /vagrant /tmp/repoclone &&

cd /tmp/repoclone &&
mv META.yml META.yml.1 &&
mv META.json META.json.1 &&
cpanm -q --installdeps --notest . &&
mv META.yml.1 META.yml &&
mv META.json.1 META.json &&

PERL5LIB="/home/vagrant/perl5/lib/perl5:$PERL5LIB" perl ./Build.PL && ./Build && ./Build test &&

exit 0;

