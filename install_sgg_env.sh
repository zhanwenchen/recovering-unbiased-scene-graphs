conda create --name dlfe python=3.7 ipython scipy h5py
# eval "$(conda shell.bash hook)"
conda activate dlfe
# quantization depends on pytorch=1.10 and above
conda install pytorch==1.10.1 torchvision==0.11.2 torchaudio==0.10.1 cudatoolkit=11.3 -c pytorch -c conda-forge
# conda install pytorch torchvision torchaudio cudatoolkit=11.1 -c pytorch-lts -c nvidia
pip install ninja yacs cython matplotlib tqdm overrides tensorboard ipykernel networkx nltk menpo opencv-python-headless
pip install setuptools==59.5.0
python -m ipykernel install --user --name=dlfe
# conda install pytorch==1.8.0 torchvision==0.9.0 torchaudio==0.8.0 cudatoolkit=11.1 -c pytorch -c conda-forge --yes
# conda install -c menpo opencv

export INSTALL_DIR=$PWD

# install pycocotools
cd $INSTALL_DIR
git clone https://github.com/cocodataset/cocoapi.git
cd cocoapi/PythonAPI
python setup.py build_ext install

# install apex
cd $INSTALL_DIR
git clone https://github.com/NVIDIA/apex.git
cd apex
git checkout 22.04-dev
# TODO: comment out setup.py line 179 about check cuda minor versions
python setup.py install --cuda_ext --cpp_ext

cd $INSTALL_DIR
python setup.py build develop

unset INSTALL_DIR
