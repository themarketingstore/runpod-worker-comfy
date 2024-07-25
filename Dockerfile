# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && apt-get autoremove -y \
    && apt-get clean -y \ 
    && rm -rf /var/lib/apt/lists/*

# Stage 2: build dependencies
FROM base AS builder
WORKDIR /build


# Install requirements from your project
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir runpod requests xformers==0.0.21 \
    && pip3 install --no-cache-dir rembg deepdiff kornia spandrel imageio_ffmpeg supervision pynvml inference opencv-python-headless matplotlib clip pillow timm pilgram



# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui
RUN pip3 install --no-cache-dir -r requirements.txt
# Install ComfyUI dependencies

FROM builder AS custom_nodes

WORKDIR /comfyui/custom_nodes

RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git \
    && git clone https://github.com/jamesWalker55/comfyui-various.git \
    && git clone https://github.com/cubiq/ComfyUI_essentials.git \
    && git clone https://github.com/rgthree/rgthree-comfy.git \
    && git clone https://github.com/storyicon/comfyui_segment_anything.git \
    && git clone https://github.com/kijai/ComfyUI-KJNodes.git \
    && git clone https://github.com/BadCafeCode/masquerade-nodes-comfyui.git \
    && git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git \
    && git clone https://github.com/crystian/ComfyUI-Crystools.git \
    && git clone https://github.com/M1kep/ComfyLiterals.git \
    && git clone https://github.com/sipherxyz/comfyui-art-venture.git \
    && git clone https://github.com/WASasquatch/was-node-suite-comfyui.git \
    && git clone https://github.com/kijai/ComfyUI-IC-Light.git \
    && git clone https://github.com/giriss/comfy-image-saver.git \
    && git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git \
    && git clone https://github.com/spacepxl/ComfyUI-Image-Filters.git \
    && git clone https://github.com/risunobushi/comfyUI_FrequencySeparation_RGB-HSV.git


# Stage 4: Final image
FROM base AS final

WORKDIR /

# Copy installed packages and ComfyUI from builder stage
COPY --from=builder /usr/local /usr/local
COPY --from=builder /comfyui /comfyui

# Copy custom nodes
COPY --from=custom_nodes /comfyui/custom_nodes /comfyui/custom_nodes

RUN for dir in /comfyui/custom_nodes/*/; do \
        if [ -f "${dir}requirements.txt" ]; then \
            pip install -r "${dir}requirements.txt"; \
        fi; \
        if [ -f "${dir}install.py" ]; then \
            python "${dir}install.py"; \
        fi; \
    done

# Create .install_complete files for nodes that use this method
RUN find /comfyui/custom_nodes -type d -exec touch {}/.install_complete \;

# Support for the network volume
COPY src/extra_model_paths.yaml /comfyui/

# Add the start script and handler
COPY src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x ./start.sh

# Start the container
CMD ["./start.sh"]