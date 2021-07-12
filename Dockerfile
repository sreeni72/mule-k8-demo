FROM sreeni72/mule-ee:4.3.0
ENV ${MULE_HOME} /opt/mule
# Deploy mule application
ARG JAR_FILE=*.jar
COPY ${JAR_FILE} ${MULE_HOME}/apps/
EXPOSE 8081