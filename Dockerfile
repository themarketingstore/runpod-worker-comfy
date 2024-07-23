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
    cmake \
    build-essential \
    && apt-get autoremove -y \
    && apt-get clean -y \ 
    && rm -rf /var/lib/apt/lists/*



# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install ComfyUI dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir xformers==0.0.21 \
    && pip3 install --no-cache-dir -r requirements.txt \
    && pip3 install --no-cache-dir runpod requests \
    && pip3 cache purge 



# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Install custom nodes
WORKDIR /comfyui/custom_nodes

RUN git clone https://github.com/evanspearman/ComfyMath.git \
    && git clone https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git \
    && git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git \
    && git clone https://github.com/ZHO-ZHO-ZHO/ComfyUI-BRIA_AI-RMBG.git \
    && git clone https://github.com/theUpsider/ComfyUI-Logic.git \
    && git clone https://github.com/jojkaart/ComfyUI-sampler-lcm-alternative.git \
    && git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git \
    && git clone https://github.com/AlekPet/ComfyUI_Custom_Nodes_AlekPet.git \
    && git clone https://github.com/Davemane42/ComfyUI_Dave_CustomNode.git \
    && git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git \
    && git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale --recursive \
    && git clone https://github.com/Ttl/ComfyUi_NNLatentUpscale.git \
    && git clone https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git \
    && git clone https://github.com/chrisgoringe/cg-use-everywhere.git \
    && git clone https://github.com/risunobushi/comfyUI_FrequencySeparation_RGB-HSV.git \
    && git clone https://github.com/Acly/comfyui-inpaint-nodes.git \
    && git clone https://github.com/jamesWalker55/comfyui-various.git \
    && git clone https://github.com/BadCafeCode/masquerade-nodes-comfyui.git \
    && git clone https://github.com/rgthree/rgthree-comfy.git \
    && git clone https://github.com/marhensa/sdxl-recommended-res-calc.git 






RUN git clone https://github.com/TheMistoAI/ComfyUI-Anyline.git && cd ComfyUI-Anyline && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/viperyl/ComfyUI-BiRefNet.git && cd ComfyUI-BiRefNet && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/kijai/ComfyUI-DepthAnythingV2.git && cd ComfyUI-DepthAnythingV2 && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/kijai/ComfyUI-IC-Light.git && cd ComfyUI-IC-Light && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/spacepxl/ComfyUI-Image-Filters.git && cd ComfyUI-Image-Filters && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && cd ComfyUI-Impact-Pack && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git && cd ComfyUI-Inspire-Pack && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/ZHO-ZHO-ZHO/ComfyUI-YoloWorld-EfficientSAM.git && cd ComfyUI-YoloWorld-EfficientSAM && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git && cd ComfyUI_essentials && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/Fihade/IC-Light-ComfyUI-Node.git && cd IC-Light-ComfyUI-Node && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/giriss/comfy-image-saver.git && cd comfy-image-saver && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/sipherxyz/comfyui-art-venture.git && cd comfyui-art-venture && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && cd comfyui_controlnet_aux && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/storyicon/comfyui_segment_anything.git && cd comfyui_segment_anything && pip3 install --no-cache-dir -r requirements.txt && cd ..
RUN git clone https://github.com/jags111/efficiency-nodes-comfyui.git && cd efficiency-nodes-comfyui && pip3 install --no-cache-dir -r requirements.txt && cd ..







# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
