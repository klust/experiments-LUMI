import os
import time
from tqdm import tqdm

import torch
import torch.nn as nn

import torchvision.models as models

import torchvision.transforms as transforms
import torchvision.datasets as datasets
import torch.utils.data as data_utils


batch_size = 32
num_workers = 8

num_images = 20000

epochs = 5

dataset_path = os.getenv("IMAGENET2012_HOME")


def get_dataset(dataset_path):

    traindir = os.path.join(dataset_path, 'train')

    normalize = transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])

    dataset = datasets.ImageFolder(
        traindir,
        transforms.Compose([
            transforms.RandomResizedCrop(224),
            transforms.RandomHorizontalFlip(),
            transforms.ToTensor(),
            normalize,
        ]))

    dataset = data_utils.Subset(dataset, torch.arange(num_images))

    dataset = datasets.FakeData(num_images, (3, 224, 224), 1000, transforms.ToTensor())

    return dataset


dataset = get_dataset(dataset_path)

loader = torch.utils.data.DataLoader(
    dataset, batch_size=batch_size, shuffle=False,
    num_workers=num_workers, pin_memory=True, sampler=None)

print(f"Dataset path .............. {dataset_path}")
print(f"Num. Images ............... {len(dataset)}")
print(f"Batch Size ................ {batch_size}")
print(f"Num. Batches .............. {len(loader)}")
print(f"Num. Workers .............. {num_workers}")
print(f"Device ....................", "GPU" if torch.cuda.is_available() else "CPU")
print(f"GPU device name ........... {torch.cuda.get_device_name(0)}")
print(f"Num. of available GPUs .... {torch.cuda.device_count()}")

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model = models.resnet18()

model = model.to(device)

criterion = nn.CrossEntropyLoss().to(device)

optimizer = torch.optim.SGD(model.parameters(), lr=0.1, momentum=0.9, weight_decay=1e-4)

scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=30, gamma=0.1)


def train(model, images, target):

    # compute output
    output = model(images)
    loss = criterion(output, target)

    # compute gradient and do SGD step
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()


# switch to train mode
model.train()

# warm-up
for i, (images, target) in enumerate(loader):
    images = images.to(device, non_blocking=True)
    target = target.to(device, non_blocking=True)
    train(model, images, target)
    if i > 5:
        break


tic = time.perf_counter()

for epoch in range(epochs):

    tic_epoch = time.perf_counter()

    for images, target in tqdm(loader):

        # move data to the same device as model
        images = images.to(device, non_blocking=True)
        target = target.to(device, non_blocking=True)

        train(model, images, target)

    tac_epoch = time.perf_counter()

    print(f"epoch {epoch} : {tac_epoch - tic_epoch} sec.")

tac = time.perf_counter()

print(f"Total Time {tac-tic} sec. ({(tac-tic)/epochs} sec./epoch)")

