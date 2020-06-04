#!/bin/sh

set -e

NAME=bson
RELEASE_NAME=bson-ruby-release
VERSION_REQUIRE=bson/version
VERSION_CONSTANT_NAME=BSON::VERSION

if ! test -f gem-private_key.pem; then
  echo "gem-private_key.pem missing - cannot release" 1>&2
  exit 1
fi

VERSION=`ruby -Ilib -r$VERSION_REQUIRE -e "puts $VERSION_CONSTANT_NAME"`

echo "Releasing $NAME $VERSION"
echo

for variant in mri jruby; do
  docker build -f release/$variant/Dockerfile -t $RELEASE_NAME-$variant .

  docker kill $RELEASE_NAME-$variant || true
  docker container rm $RELEASE_NAME-$variant || true

  docker run -d --name $RELEASE_NAME-$variant -it $RELEASE_NAME-$variant

  docker exec $RELEASE_NAME-$variant /app/release/$variant/build.sh

  if test $variant = jruby; then
    docker cp $RELEASE_NAME-$variant:/app/$NAME-$VERSION-java.gem .
  else
    docker cp $RELEASE_NAME-$variant:/app/$NAME-$VERSION.gem .
  fi

  docker kill $RELEASE_NAME-$variant
done

echo
echo Built: $NAME-$VERSION.gem
echo Built: $NAME-$VERSION-java.gem
echo

git tag -a v$VERSION -m "Tagging release: $VERSION"
git push origin v$VERSION

gem push $NAME-$VERSION.gem
gem push $NAME-$VERSION-java.gem
