# Update Ensembl IDs

## Summary

Update gene Ensembl data in PanelApp.

## Description

Use Ensembl ID update data in JSON format to update genes.
The data can be either uploaded as a file to the upload bucket ${ upload_bucket },
or provided as a string. In either case the data has to be JSON encoded.

Example:

```json
{
  "SCO2": {
    "GRch38": {
      "107": {
        "location": "22:50523568-50526461",
        "ensembl_id": "ENSG00000284194"
      }
    }
  }
}
```

## Scope

Environment: **${ env }**

Terraform workspace: **${ tf_workspace }**

## I/O

### Input Parameter

**Data**: (Either) Update data as JSON.

**Path**: (Or) Path to data file in the upload bucket `${ upload_bucket }`.

### Output

None

### Files

* JSON data provided in Data parameter is written to
  `s3://${ upload_bucket }/ensembl_id_update/<date>/ssm:automation:<execution_id>/update_data.json`
* Changes are written to `s3://${ log_bucket }/ensembl_id_update/<date>/ssm:automation:<execution_id>/logs/changes.log`
* Errors:`s3://${ log_bucket }/ensembl_id_update/<date>/ssm:automation:<execution_id>/logs/errors.log`

## Logging

CloudWatch log group: `${ log_group }`

## Limitations

None
