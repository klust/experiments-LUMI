#!/usr/bin/env python
# coding: utf-8
import os

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
    print('__Number CUDA Devices:', torch.cuda.device_count())
    print('__CUDA Device Name:',torch.cuda.get_device_name(0))
    print('__CUDA Device Total Memory [GB]:',torch.cuda.get_device_properties(0).total_memory/1e9)


# Number of instruction examples for the fine-tuning. N=100,500,1000,5000,10000
N=100
Ngpus=torch.cuda.device_count()

# Load the dataset for finie-tuning 
dataset = load_from_disk(os.path.join("/leonardo_work/EUHPC_T_Boot-AI/datasets", "imdb_v2_" + str(N) + ".hf"))
print("Dataset imported")
print(dataset)

train_example = dataset['train'][0]  # This retrieves the first example in the training dataset

# Now, print the example
print("Label:", train_example['label'])
print("Text:", train_example['text'])


# Read the file for the evaluation of the fine-tuned model
csv_file_path = os.path.join("/leonardo_work/EUHPC_T_Boot-AI/datasets", "movie_reviews_100_unique.csv")
df_eval = pd.read_csv(csv_file_path)


# display % of training data with label=1
np.array(dataset['train']['label']).sum()/len(dataset['train']['label'])


#model_checkpoint = 'roberta-base'
model_checkpoint = 'distilbert-base-uncased' # you can alternatively use roberta-base but this model is bigger thus training will take longer

# define label maps
id2label = {0: "Negative", 1: "Positive"}
label2id = {"Negative":0, "Positive":1}

# generate classification model from model_checkpoint
model = AutoModelForSequenceClassification.from_pretrained(
    model_checkpoint, num_labels=2, id2label=id2label, label2id=label2id)


print("*** Some Model Information ***")
print(model)

# create tokenizer
tokenizer = AutoTokenizer.from_pretrained(model_checkpoint, add_prefix_space=True)

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
tokenized_dataset = dataset.map(tokenize_function, batched=True)


# create data collator
data_collator = DataCollatorWithPadding(tokenizer=tokenizer)


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
cm = confusion_matrix(actual_labels, predicted_labels_untrained, labels=["Positive", "Negative"])           
fig, ax = plt.subplots(figsize=(8, 8))
sns.heatmap(cm, annot=True, fmt="d", ax=ax, cmap="Blues", xticklabels=["Positive", "Negative"], yticklabels=["Positive", "Negative"])
ax.set_xlabel("Predicted Labels")
ax.set_ylabel("True Labels")
ax.set_title("Confusion Matrix")
plt.savefig("ConfusionMatrixNotTrained"+str(N) + "_" + str(Ngpus)+".png")

#Define a 1-value metric for final evaluation
acc = (cm[0, 0] + cm[1, 1]) / cm.sum()
print(f"Accuracy pre-trained model: {acc}")



# Now we start the Fine-Tuning. We want to use PEFT with LORA

# Here we define the configuration for PEFT
# r is the intrinsic rank of the model
# lora_alpha is the the alpha parameter for Lora scaling
# lora_dropout is  dropout probability for Lora layers

peft_config = LoraConfig(task_type="SEQ_CLS",
                        r=4,
                        lora_alpha=32,
                        lora_dropout=0.01,
                        target_modules = ['q_lin'])


model = get_peft_model(model, peft_config)
model.print_trainable_parameters()


# Define the hyperparameters of the pre-trained model
lr = 1e-3
batch_size = 4
num_epochs = 15


# define training arguments TrainingArguments is the subset of the arguments used during he training loop
training_args = TrainingArguments(
    output_dir=model_checkpoint + "-lora-text-classification",
    learning_rate=lr,
    per_device_train_batch_size=batch_size,
    per_device_eval_batch_size=batch_size,
    num_train_epochs=num_epochs,
    weight_decay=0.01,
    evaluation_strategy="epoch",
    save_strategy="no",  # This tells the Trainer not to save any checkpoints
    logging_dir='./logs',  # Specify the directory for TensorBoard logs if you're using TensorBoard
    logging_steps=50,  # How often to log metrics for TensorBoard
)


# creater trainer object
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=tokenized_dataset["train"],
    eval_dataset=tokenized_dataset["validation"],
    tokenizer=tokenizer,
    data_collator=data_collator, # this will dynamically pad examples in each batch to be equal length
    compute_metrics=compute_metrics,
)


# Now ready to fine-tune the model 
start_t=time.time()
trainer.train()
end_t=time.time()-start_t

# And then apply the fine-tuned model to the evaluation dataset
model.to('cpu') 


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
cm = confusion_matrix(actual_labels, predicted_labels_trained, labels=["Positive", "Negative"])
fig, ax = plt.subplots(figsize=(8, 8))
sns.heatmap(cm, annot=True, fmt="d", ax=ax, cmap="Blues", xticklabels=["Positive", "Negative"], yticklabels=["Positive", "Negative"])
ax.set_xlabel("Predicted Labels")
ax.set_ylabel("True Labels")
ax.set_title("Confusion Matrix")
plt.savefig("ConfusionMatrixTrained" +str(N)+ "_" + str(Ngpus) + ".png")

acc = (cm[0, 0] + cm[1, 1]) / cm.sum()
print(f"Accuracy fine tuned model: {acc}")


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
