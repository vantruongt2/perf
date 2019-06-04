docker build -t jmbase -f base/dockerfile . \
  && docker build -t jmmaster -f master/dockerfile . \
  && docker build -t jmslave -f slave/dockerfile . \