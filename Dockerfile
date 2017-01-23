FROM ssig33/ruby-imagemagick-groonga
RUN mkdir /app
WORKDIR /app
COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle -j9
COPY . ./

EXPOSE 5000

CMD RACK_ENV=production ruby app.rb -p 5000 -o 0.0.0.0
