docker build -t jmbase -f base/Dockerfile . \
  && docker build -t jmmaster -f master/Dockerfile . \
  && docker build -t jmslave -f slave/Dockerfile . \