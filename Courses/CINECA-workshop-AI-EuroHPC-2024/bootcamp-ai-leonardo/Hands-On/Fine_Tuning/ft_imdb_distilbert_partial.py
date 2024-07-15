#!/usr/bin/env python
# coding: utf-8

from datasets import load_dataset, DatasetDict, Dataset, load_from_disk

import datasets

from transformers import (
    AutoTokenizer,
    AutoConfig, 
    AutoModelForSequenceClassification,
    DataCollatorWithPadding,
    TrainingArguments,
    Trainer)

from peft import PeftModel, PeftConfig, get_peft_model, LoraConfig
import evaluate
import torch
import numpy as np
import pandas as pd
from sklearn.metrics import confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns
import time

use_cuda = torch.cuda.is_available()
if use_cuda:
    print('__CUDNN VERSION:', torch.backends.cudnn.version())
    print('__Number CUDA Devices:', ###########################)
    print('__CUDA Device Name:',#########################)
    print('__CUDA Device Total Memory [GB]:',torch.cuda.get_device_properties(0).total_memory/1e9)


# Number of instruction examples for the fine-tuning. N=100,500,1000,5000,10000
N=100
Ngpus=torch.cuda.device_count()

# Load the dataset for finie-tuning 
dataset = #########################

# Read the file for the evaluation of the fine-tuned model
csv_file_path = "movie_reviews_100_unique.csv"
df_eval = ##############################

          

# Load the base model
model_checkpoint = ###########
          
# define label maps


# generate classification model from model_checkpoint
model = ############


print("*** Some Model Information ***")
print(model)

# create tokenizer
tokenizer = ##########################

# add pad token if none exists
if tokenizer.pad_token is None:
    tokenizer.add_special_tokens({'pad_token': '[PAD]'})
    model.resize_token_embeddings(len(tokenizer))


# create tokenize function
def tokenize_function(examples):
    # extract text
    text = examples["text"]

    #tokenize and truncate text
    tokenizer.truncation_side = "left"
    tokenized_inputs = tokenizer(
        text,
        return_tensors="np",
        truncation=True,
        max_length=512
    )

    return tokenized_inputs


# tokenize training and validation datasets
tokenized_dataset = ########################


# create data collator
data_collator = ############################


# evaluation
# import accuracy evaluation metric
accuracy = evaluate.load("accuracy")

# define an evaluation function to pass into trainer later
def compute_metrics(p):
    predictions, labels = p
    predictions = np.argmax(predictions, axis=1)
    return {"accuracy": accuracy.compute(predictions=predictions, references=labels)}


# Apply untrained model to the evaluation dataset to see performances pre and post fine-tuning
# Lists to store predicted and actual labels
predicted_labels_untrained = []
predicted_labels_trained = []
actual_labels = []


for index, row in df_eval.iterrows():
    text, real_label = row['text'], row['label']
    # Tokenize text and compute logits
    inputs = tokenizer.encode(text, return_tensors="pt", max_length=512, truncation=True)
    with torch.no_grad():  # Ensure no gradients are computed to save memory and computations
        logits = model(inputs).logits
    # Convert logits to label
    predictions = torch.argmax(logits, dim=-1)
    predicted_label = id2label[predictions.item()]
    predicted_labels_untrained.append(predicted_label)
    actual_labels.append(real_label)


# Compute and plot confusion matrix    
cm= ##########################################

#Define a 1-value metric for final evaluation
acc = #######################################
print(f"Accuracy pre-trained model: {acc}")



# Now we start the Fine-Tuning. We want to use PEFT with LORA


peft_config = #################

model = #########################
          
model.print_trainable_parameters()


# Define the hyperparameters of the pre-trained model
#########################


# define training arguments TrainingArguments is the subset of the arguments used during he training loop
training_args = ####################


# creater trainer object
trainer = #########################


# Now ready to fine-tune the model 
############################

# And then apply the fine-tuned model to the evaluation dataset
##############################


print("Trained Model predictions vs. real labels:")
print("----------------------------------")
for index, row in df_eval.iterrows():
    text, real_label = row['text'], row['label']
    # Tokenize text and compute logits  
    inputs = tokenizer.encode(text, return_tensors="pt", max_length=512, truncation=True)
    with torch.no_grad():  # Ensure no gradients are computed to save memory and computations                   
        logits = model(inputs).logits
    # Convert logits to label                               
    predictions = torch.argmax(logits, dim=-1)
    predicted_label = id2label[predictions.item()]
    predicted_labels_trained.append(predicted_label)

# Compute and plot confusion matrix
cm = #############################


#Save some final recap info
data_to_save={
    "Batch Size": [batch_size],  # Another example column
    "Learning Rate":[lr],
    "Accuracy FT Model": [acc],
    "Ngpus": [torch.cuda.device_count()],
    "Train time":end_t
}

# Create a DataFrame
df = pd.DataFrame(data_to_save)
df.to_csv("summary_" + str(N) + "_" + str(Ngpus) + ".csv", index=False)
