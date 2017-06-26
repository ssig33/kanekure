FROM ssig33/ruby-imagemagick-groonga
RUN mkdir /app
WORKDIR /app
COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle -j9
COPY . ./

ENV PORT=5000

CMD RACK_ENV=production ruby app.rb -p $PORT -o 0.0.0.0
