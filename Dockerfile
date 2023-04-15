FROM ruby:3.0.2

RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get update && apt-get install -y nodejs
RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y yarn
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN mkdir /repogitory_name
WORKDIR /repogitory_name
ADD Gemfile /repogitory_name/Gemfile
ADD Gemfile.lock /repogitory_name/Gemfile.lock
RUN bundle install
ADD package.json yarn.lock /repogitory_name/
RUN yarn install --check-files
ADD . /repogitory_name
