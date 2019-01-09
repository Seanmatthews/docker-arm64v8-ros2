FROM arm64v8/ubuntu:xenial

# setup utils
RUN apt-get clean && apt-get update 
RUN apt-get install -y locales curl lsb-release apt-utils

# set environment
RUN locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
# ENV CC clang
# ENV CXX clang++
ENV DEBIAN_FRONTEND noninteractive
ENV ROS_DISTRO crystal

# Colcon
RUN sh -c 'echo "deb [arch=amd64,arm64] http://repo.ros2.org/ubuntu/main `lsb_release -cs` main" > \
           /etc/apt/sources.list.d/ros2-latest.list'
RUN curl http://repo.ros2.org/repos.key | apt-key add -

# install packages
RUN apt-get update && apt-get install -q -y \
  build-essential \
  cmake \
  git \
  python3-colcon-common-extensions \
  python3-pip \
  python-rosdep \
  python3-vcstool \
  wget	

# upgrade pip
RUN pip3 install --upgrade pip

# install some pip packages needed for testing
RUN python3 -m pip install -U \
  argcomplete \
  flake8 \
  flake8-blind-except \
  flake8-builtins \
  flake8-class-newline \
  flake8-comprehensions \
  flake8-deprecated \
  flake8-docstrings \
  flake8-import-order \
  flake8-quotes \
  git+https://github.com/lark-parser/lark.git@0.7b \
  pytest-repeat \
  pytest-rerunfailures \
  pytest \
  pytest-cov \
  pytest-runner \
  setuptools

# install Fast-RTPS dependencies
RUN apt-get install --no-install-recommends -y \
  libasio-dev \
  libtinyxml2-dev

# install DDS implementations
RUN apt-get install --no-install-recommends -y \
  libopensplice69

# clang compiler
# RUN apt-get install -y clang

# get ros2 code
RUN mkdir -p ~/ros2ws/src
WORKDIR ~/ros2ws
RUN wget https://raw.githubusercontent.com/ros2/ros2/release-latest/ros2.repos
RUN vcs import ~/ros2ws/src < ros2.repos

# install dependencies using rosdep
RUN rosdep init && rosdep update
RUN rosdep install --from-paths ~/ros2ws/src --ignore-src --rosdistro crystal -y --skip-keys "\
  console_bridge \
  fastcdr fastrtps \
  libopensplice67 \
  libopensplice69 \
  python3-lark-parser \
  rti-connext-dds-5.3.1 \
  urdfdom_headers"

# leftover dependencies
RUN apt-get install --no-install-recommends -y \
  libpoco-dev

# build ros2
RUN colcon build --symlink-install --cmake-force-configure \
           --packages-ignore test_communication \
           --packages-ignore-regex "(^rviz|^rqt|^qt_|.*connext_).*" \
           --base-paths ~/ros2ws/

# cleanup
RUN rm -rf /var/lib/apt/lists/*

# entrypoint
COPY ./ros_entrypoint.sh /
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
