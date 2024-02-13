#!/bin/sh

set -e

NAME=bson
RELEASE_NAME=bson-ruby-release
VERSION_REQUIRE=bson/version
VERSION_CONSTANT_NAME=BSON::VERSION
CMD=echo

if ! test -f gem-private_key.pem; then
  echo "gem-private_key.pem missing - cannot release" 1>&2
  exit 1
fi

if test -z "$PRODUCTION_RELEASE"; then
  echo "PRODUCTION_RELEASE is not set. The script will run in 'dry run'"
  echo "mode. The gems will be built, but not actually published. To"
  echo "publish the gems, set the PRODUCTION_RELEASE env variable to 1 and"
  echo "re-run this script."
else
  echo "PRODUCTION_RELEASE is set. Gems will be built and published."
  CMD=''
fi

echo
read -p "-- Press RETURN to continue, or CTRL-C to abort --"

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

if test -z "$PRODUCTION_RELEASE"; then
  echo "*** SHOWING COMMANDS IN 'DRY RUN' MODE ***"
  echo
fi

$CMD git tag -a v$VERSION -m "Tagging release: $VERSION"
$CMD git push origin v$VERSION

$CMD gem push $NAME-$VERSION.gem
$CMD gem push $NAME-$VERSION-java.gem
