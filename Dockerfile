FROM node:12 as node
FROM ruby:3.0.2

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /opt/yarn-* /opt/yarn/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -fs /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -fs /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && ln -fs /opt/yarn/bin/yarn /usr/local/bin/yarn \
    && ln -fs /opt/yarn/bin/yarnpkg /usr/local/bin/yarnpkg

RUN mkdir /repogitory_name
WORKDIR /repogitory_name

ADD Gemfile /repogitory_name/Gemfile
ADD Gemfile.lock /repogitory_name/Gemfile.lock
RUN bundle install

ADD package.json yarn.lock /repogitory_name/
RUN yarn install --check-files

ADD . /repogitory_name
