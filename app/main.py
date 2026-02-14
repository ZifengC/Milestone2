from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np
import os

app = FastAPI(title="Iris Prediction Service")

# Load model (ensure path matches Docker container structure)
model_path = os.path.join(os.path.dirname(__file__), "model.joblib")
model = joblib.load(model_path)

class IrisInput(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/predict")
def predict(data: IrisInput):
    features = np.array([[
        data.sepal_length, 
        data.sepal_width, 
        data.petal_length, 
        data.petal_width
    ]])
    prediction = model.predict(features)
    return {"prediction": int(prediction[0])}